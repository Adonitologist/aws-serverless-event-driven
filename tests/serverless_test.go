package test

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAwsServerlessEventDriven(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir:    "../",
		TerraformBinary: "terraform",
		Vars: map[string]interface{}{
			"environment": "test",
		},
	}

	// Clean up resources automatically after the test completes
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure stack
	terraform.InitAndApply(t, terraformOptions)

	// Retrieve outputs
	apiEndpoint := terraform.Output(t, terraformOptions, "api_gateway_endpoint")
	tableName := terraform.Output(t, terraformOptions, "dynamodb_table_name")

	assert.NotEmpty(t, apiEndpoint)
	assert.NotEmpty(t, tableName)

	// Validate HTTP API Endpoint Accessibility with retries
	url := fmt.Sprintf("%s/orders", apiEndpoint)

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		},
		Timeout: 5 * time.Second,
	}

	// Prepare mock payload for the API Gateway EventBridge integration
	requestBody, _ := json.Marshal(map[string]interface{}{
		"orderId": "evt-77492-test",
		"amount":  250.50,
	})

	// Retry HTTP check until API Gateway stage propagation completes
	maxRetries := 20
	var resp *http.Response
	var err error

	for i := 0; i < maxRetries; i++ {
		// New buffer must be created on each retry
		resp, err = client.Post(url, "application/json", bytes.NewBuffer(requestBody))
		if err == nil && resp.StatusCode == http.StatusOK {
			break
		}
		time.Sleep(3 * time.Second)
	}

	assert.NoError(t, err, "API Gateway endpoint should be reachable")
	if resp != nil {
		defer resp.Body.Close()
		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP 200 OK from API Gateway POST route")
	}
}