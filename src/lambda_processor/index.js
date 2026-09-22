const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

// Initialize DynamoDB Client with X-Ray tracing natively supported
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  console.log("Batch size received:", event.Records.length);

  for (const record of event.Records) {
    try {
      // 1. Unpack the SQS wrapper directly (SNS wrapper bypassed via raw_message_delivery)
      const sqsBody = JSON.parse(record.body);
      
      // 2. Extract the EventBridge detail (the actual JSON sent to API Gateway)
      const orderData = sqsBody.detail;
      const orderId = orderData.orderId || Math.random().toString(36).substring(2, 15);

      const command = new PutCommand({
        TableName: process.env.TABLE_NAME,
        Item: {
          orderId: orderId,
          createdAt: new Date().toISOString(),
          status: "PROCESSED",
          payload: orderData
        }
      });

      await ddbDocClient.send(command);
      console.log(`Successfully persisted order: ${orderId}`);
      
    } catch (err) {
      console.error("Failed to process record. Sending to DLQ.", err);
      // Throwing an error marks the SQS message processing as failed.
      // After maxReceiveCount is hit, SQS automatically moves it to the DLQ.
      throw err; 
    }
  }
};