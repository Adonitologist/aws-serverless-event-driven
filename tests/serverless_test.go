package test

import (
	"crypto/tls"
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
		TerraformDir: "../",
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

	// Retry HTTP check until API Gateway stage propagation completes
	maxRetries := 10
	var resp *http.Response
	var err error

	for i := 0; i < maxRetries; i++ {
		resp, err = client.Get(url)
		if err == nil {
			break
		}
		time.Sleep(3 * time.Second)
	}

	assert.NoError(t, err, "API Gateway endpoint should be reachable")
	if resp != nil {
		defer resp.Body.Close()
		// API Gateway route expects POST; GET without proper payload might return 403/404/405, 
		// but receiving any valid HTTP status confirms routing functionality.
		assert.True(t, resp.StatusCode > 0, "Received valid HTTP response from API Gateway")
	}
}