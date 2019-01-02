var config = require('./config.js');
var request = require('request');
var async = require('async');
var botConfig = require('./abmspoc-e6fa7-9b84f81aec59.json');
var requestWithJWT = require('google-oauth-jwt').requestWithJWT();
var _ = require('lodash');
var Speech = require('ssml-builder');
var R = require("r-script");

var self = {
    "queryDialogflow": function (rawQuery) {
        console.log('inside queryDialogflow');
        return new Promise(function (resolve, reject) {
            var options = {
                //proxy: 'http://gmdvproxy.acml.com:8080/',
                method: 'POST',
                url: 'https://api.dialogflow.com/v1/query?v=20150910',
                headers:
                {
                    'content-type': 'application/json',
                    authorization: 'Bearer ' + 'c914a0d867e4400aafd44b79249e64f8'
                },
                body:
                {
                    lang: 'en',
                    query: rawQuery,
                    sessionId: '12345',
                    timezone: 'America/New_York'
                },
                json: true
            };
            request(options, function (error, response, body) {
                if (error) {
                    console.log(error);
                    reject("Something went wrong when processing your request. Please try again.");
                }
                console.log(body);
                resolve(body.result);
            });
        });
    },
    "salesByRegionReport": function (is_historic,productName,year,quarter,fundType,product) {
        console.log("inside helper salesByRegionReport");
        return new Promise(function (resolve, reject) {
            async.waterfall([
                function (cb) {
                    var options = new R("E:\bimal\abpoc\test_r_node_module\Quarter_Sale_prediction.R")
                              .data(is_historic,productName,year,quarter,fundType,product)
                              .callSync(function (err, resp) {
                   });
                    request(options, function (error, response, body) {
                        if (error) {
                            reject("Auth request error", error);
                        }
                        console.log('FIRST HEADER', response.headers['set-cookie']);
                        console.log('HEADER x-mstr-authtoken', response.headers['x-mstr-authtoken']);
                        cb(null, response.headers['x-mstr-authtoken'], response.headers['set-cookie']);
                        var salesReport = self.buildSalesReport(body);
                        resolve(salesReport);
                    });
                },
            ], function (error) {
                if (error) {
                    console.log("ERROR: ", error);
                    reject("Something went wrong!");
                }
            });
        });
    },
    "buildSalesReport": function (data) {
        console.log("inside helper buildEventReport");
        var result = { "records": [], "columns": [] };
        _.forEach(data.result.definition.attributes, function (value, key) {
            result.columns.push(value.name);
        });
        _.forEach(data.result.definition.metrics, function (value, key) {
            result.columns.push(value.name);
        });
        result = self.buildLinearArrayFromTree(data.result.data.root.children, result, [], 0);
        console.log("RES", JSON.stringify(result));

        var speech = new Speech();
        speech.say("Here are the sales report details").pause("500ms");
        _.forEach(result.records, function (value, key) {
            if (value.length == result.columns.length) {
                speech.sayAs({ word: key + 1, interpret: 'ordinal' });
                for (var j = 0; j < result.columns.length; j++) {
                    var sentence = "", field = "", dateArray = [];
                    if (typeof value[j] != "undefined") {
                        field = value[j].name;
                        if (field == "") {
                            sentence = result.columns[j] + " none";
                            speech.sentence(sentence);
                        } else {
                            sentence = result.columns[j] + " " + value[j].name;
                            speech.sentence(sentence);
                        }
                    } else {
                        sentence = result.columns[j] + " none";
                        speech.sentence(sentence);
                    }
                }
                speech.pause("500ms");
            }
        });
        var speechOutput = speech.ssml();
        return speechOutput;
    },
    "generateAccessToken": function () {
        return new Promise((resolve, reject) => {
            requestWithJWT({
                url: 'https://www.googleapis.com/drive/v2/files',
                jwt: {
                    email: botConfig.client_email,
                    key: botConfig.private_key,
                    scopes: ['https://www.googleapis.com/auth/cloud-platform']
                }
            }, function (err, res, body) {
                if (err) {
                    reject(err);
                }
                resolve(body);
            });
        });
    }
};

module.exports = self;
console.log(self.queryDialogflow('Hello'));
console.log(self.salesByRegionReport(1,'SBI Mutual Funds',2012,'Q1 2012','Balanced Funds','SBI CREDIT RISK FUND - DIRECT PLAN -GROWTH'));
