const { APIGatewayClient, GetExportCommand } = require("@aws-sdk/client-api-gateway");
const express = require('express')
const serverless = require('serverless-http')
const swaggerUI = require('swagger-ui-express')
const compression = require('compression');

const client = new APIGatewayClient({apiVersion: '2015-07-09'});

const app = express()

module.exports.handler = async (event, context) => {
    const apiId = process.env.API_ID; //event.requestContext.apiId
    const stage = process.env.STAGE; //
    console.log(event, {depth:null})// event.requestContext.stage

    var params = {
        exportType: 'swagger',
        restApiId: apiId,
        stageName: stage,
        accepts: 'application/json'
    };
    // const command = new GetExportCommand(params);
    // console.log(command, {depth:null})
    // const response = await client.send(command);
    // console.log("response>>>>>>>>>>>>>>>>>>>>")
    // console.log(JSON.stringify(response))
    // const jsonString = Buffer.from(response.body).toString('utf8')
    // var swaggerJson = JSON.parse(jsonString)

    // delete swaggerJson['paths']['/v1/api-docs/{proxy+}']
    // delete swaggerJson['paths']['/v1/api-docs']
    app.use(compression({
        threshold: 0
    }));
    app.use('/core/v1/api-docs', swaggerUI.serve, swaggerUI.setup({
        "swagger" : "2.0",
        "info" : {
            "description" : "This is a test API Gateway to demonstrate the use of Swagger UI",
            "version" : "1.0",
            "title" : "serverless-swagger-ui"
        },
        "host" : "b9vwch90p0.execute-api.ap-south-1.amazonaws.com",
        "basePath" : "/dev",
        "schemes" : [ "https" ],
        "paths" : {
            "/core/{proxy+}" : {
                "get" : {
                    "parameters" : [ {
                        "name" : "proxy",
                        "in" : "path",
                        "required" : true,
                        "type" : "string"
                    } ],
                    "responses" : { }
                }
            },
            "/orders" : {
                "get" : {
                    "produces" : [ "application/json" ],
                    "parameters" : [ {
                        "name" : "orderDate",
                        "in" : "query",
                        "required" : false,
                        "type" : "string"
                    }, {
                        "name" : "userid",
                        "in" : "query",
                        "required" : false,
                        "type" : "string"
                    } ],
                    "responses" : {
                        "200" : {
                            "description" : "200 response",
                            "schema" : {
                                "$ref" : "#/definitions/ordersResponse"
                            }
                        }
                    }
                }
            },
            "/users" : {
                "get" : {
                    "produces" : [ "application/json" ],
                    "parameters" : [ {
                        "name" : "orderDate",
                        "in" : "query",
                        "required" : false,
                        "type" : "string"
                    }, {
                        "name" : "userid",
                        "in" : "query",
                        "required" : false,
                        "type" : "string"
                    } ],
                    "responses" : {
                        "200" : {
                            "description" : "200 response",
                            "schema" : {
                                "$ref" : "#/definitions/ordersResponse"
                            }
                        }
                    }
                }
            }
        },
        "definitions" : {
            "ordersResponse" : {
                "type" : "object",
                "properties" : {
                    "orders" : {
                        "type" : "array",
                        "items" : {
                            "$ref" : "#/definitions/ordersResponseObject"
                        }
                    },
                    "queryParameters" : {
                        "$ref" : "#/definitions/ordersQueryParameters"
                    }
                },
                "title" : "Orders Response"
            },
            "ordersDataObject" : {
                "type" : "object",
                "properties" : {
                    "user" : {
                        "type" : "string"
                    },
                    "shippingAddress" : {
                        "type" : "string"
                    },
                    "invoiceAddress" : {
                        "type" : "string"
                    },
                    "orderDate" : {
                        "type" : "string",
                        "format" : "date"
                    }
                },
                "title" : "Orders Data Object"
            },
            "ordersQueryParameters" : {
                "type" : "object",
                "properties" : {
                    "userid" : {
                        "type" : "string"
                    },
                    "orderDate" : {
                        "type" : "string",
                        "format" : "date"
                    }
                },
                "title" : "Orders Query Parameters"
            },
            "ordersResponseObject" : {
                "type" : "object",
                "properties" : {
                    "orderId" : {
                        "type" : "number"
                    },
                    "data" : {
                        "$ref" : "#/definitions/ordersDataObject"
                    }
                },
                "title" : "Orders Response Object"
            }
        }
    }))
    const handler = serverless(app)
    const ret = await handler(event, context)
    console.log(JSON.stringify(ret))
    return ret
};

// const AWS = require('aws-sdk')
// const express = require('express')
// const serverless = require('serverless-http')
// const swaggerUI = require('swagger-ui-express')
//
// var apigateway = new AWS.APIGateway({apiVersion: '2015-07-09'});
//
// const app = express()
//
// module.exports.handler = async (event, context) => {
//     const apiId = event.requestContext.apiId
//     const stage = event.requestContext.stage
//
//     var params = {
//         exportType: 'oas30',
//         restApiId: apiId,
//         stageName: stage,
//         accepts: 'application/json'
//     };
//
//     var getExportPromise = await apigateway.getExport(params).promise();
//
//     var swaggerJson = JSON.parse(getExportPromise.body)
//
//     delete swaggerJson['paths']['/api-docs/{proxy+}']
//     delete swaggerJson['paths']['/api-docs']
//
//     app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(swaggerJson))
//     const handler = serverless(app)
//     const ret = await handler(event, context)
//     return ret
// };