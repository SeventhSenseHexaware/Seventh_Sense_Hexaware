const { List, actionssdk } = require('actions-on-google')
const app = actionssdk(/*{ debug: true }*/);
var helper = require('./helper');

app.intent('actions.intent.MAIN', conv => {
    conv.ask('<speak>Hi <break time="200ms"/> I am Simon, your virtual assistant. Please tell me how can I help you</speak>');
    conv.ask(new List({
        title: 'Please choose',
        items: {
            ['SELECTION_KEY_GET_SALES_INFO']: {
                synonyms: [
                    'Get sales information',
                ],
                title: 'Get sales information',
                description: 'Lets you get your sales related information'
            },
            ['PREDICTION']: {
                synonyms: [
                    'Get prediction',
                ],
                title: 'Get prediction',
                description: 'Lets get your prediction'
            }
        },
    }));
});

app.intent('actions.intent.OPTION', (conv, params, option) => {
    console.log(option);
    switch (option) {
        case 'SELECTION_KEY_GET_SALES_INFO':
            conv.ask('<speak> Please say a fund name starting with the word Sales </speak>')    
            break;
        case 'PREDICTION':
            conv.ask('<speak> Please say a fund name starting with the word name for prediction </speak>')
            break;
    }
});

app.intent('actions.intent.CLOSE', (conv, input) => {
    conv.ask('Happy to help you.See you later!').close();
});

app.intent('actions.intent.CANCEL', (conv, input) => {
    conv.ask('Happy to help you.See you later!').close();
});

app.intent('actions.intent.TEXT', (conv, input) => {
    console.log("Raw input: " + conv.input.raw);
    console.log("Input: " + input);
    if (input === 'bye' || input === 'goodbye' || input == 'close simon'|| input == 'close' || input == 'cancel') {
        conv.ask('Happy to help you.See you later!').close();
        return;
    } else if (input.startsWith('name')){
        conv.user.storage.Product = input;
        conv.ask('<speak> Please say confirmed or a year for Prediction starting with the word Year </speak>');
    } else if (input.startsWith('year')){
        conv.user.storage.Year = input;
        conv.ask('<speak> Please say confirmed or a quarter for Prediction Starting with the word Quarter </speak>)       
    } else if (input.startsWith('quarter')){
        conv.user.storage.Quarter = input;
        conv.ask('<speak> Please say confirmed or a Product Type for Prediction Starting with the word product </speak>)       
    } else if (input.startsWith('product')){
        conv.user.storage.Product = input;
        conv.ask('<speak> Please say confirmed or a fund Type for Prediction Starting with the word Fund Type </speak>)       
    } else if (input.startsWith('fund')){
        conv.user.storage.FundType = input; helper.salesByRegionReport(conv.user.storage.Product,conv.user.storage.Year,conv.user.storage.Quarter,conv.user.storage.FundType,'').then((result) => {
                    console.log('event report result', result);
                    conv.ask(result);
                }).catch((err) => {
                    console.log("EVENT REPORT - some error occured");
                    conv.ask("Sorry, something went wrong");
                });
                    conv.user.storage={};
                break;
    } else if (input === 'confirmed'){ helper.salesByRegionReport(conv.user.storage.Product,conv.user.storage.Year,conv.user.storage.Quarter,conv.user.storage.FundType,conv.user.storage.Product).then((result) => {
                    console.log('event report result', result);
                    conv.ask(result);
                }).catch((err) => {
                    console.log("EVENT REPORT - some error occured");
                    conv.ask("Sorry, something went wrong");
                });
                    conv.user.storage={};
                break;
    } else if (input === 'sales'){ 
        conv.user.storage.Sales = input; helper.salesByRegionReport(conv.user.storage.Sales,'','','','').then((result) => {
                    console.log('event report result', result);
                    conv.ask(result);
                }).catch((err) => {
                    console.log("EVENT REPORT - some error occured");
                    conv.ask("Sorry, something went wrong");
                });
                    conv.user.storage={};
                break;).catch((err) => {
        res.send(err);
    });
});

module.exports = app;