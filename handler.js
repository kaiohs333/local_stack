'use strict';

const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');
const itemsService = require('./itemsService');

// Joi schemas for validation
const itemSchema = Joi.object({
    name: Joi.string().min(3).required(),
    description: Joi.string().min(5).optional(),
});

module.exports.createItem = async (event) => {
    try {
        const reqBody = JSON.parse(event.body);
        const { error } = itemSchema.validate(reqBody);

        if (error) {
            return {
                statusCode: 400,
                body: JSON.stringify({ message: error.details[0].message }),
            };
        }

        const id = uuidv4();
        const item = { id, ...reqBody, createdAt: new Date().toISOString() };
        await itemsService.createItem(item);

        return {
            statusCode: 201,
            body: JSON.stringify(item),
        };
    } catch (error) {
        console.error('Error creating item:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Could not create item' }),
        };
    }
};

module.exports.getAllItems = async () => {
    try {
        const items = await itemsService.getAllItems();
        return {
            statusCode: 200,
            body: JSON.stringify(items),
        };
    } catch (error) {
        console.error('Error getting all items:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Could not fetch items' }),
        };
    }
};

module.exports.getItem = async (event) => {
    try {
        const { id } = event.pathParameters;
        const item = await itemsService.getItem(id);

        if (!item) {
            return {
                statusCode: 404,
                body: JSON.stringify({ message: 'Item not found' }),
            };
        }

        return {
            statusCode: 200,
            body: JSON.stringify(item),
        };
    } catch (error) {
        console.error('Error getting item:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Could not fetch item' }),
        };
    }
};

module.exports.updateItem = async (event) => {
    try {
        const { id } = event.pathParameters;
        const reqBody = JSON.parse(event.body);
        const { error } = itemSchema.validate(reqBody);

        if (error) {
            return {
                statusCode: 400,
                body: JSON.stringify({ message: error.details[0].message }),
            };
        }

        const updatedItem = { ...reqBody, updatedAt: new Date().toISOString() };
        const result = await itemsService.updateItem(id, updatedItem);

        if (!result) {
            return {
                statusCode: 404,
                body: JSON.stringify({ message: 'Item not found' }),
            };
        }

        return {
            statusCode: 200,
            body: JSON.stringify(result),
        };
    } catch (error) {
        console.error('Error updating item:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Could not update item' }),
        };
    }
};

module.exports.deleteItem = async (event) => {
    try {
        const { id } = event.pathParameters;
        await itemsService.deleteItem(id);

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Item deleted successfully' }),
        };
    } catch (error) {
        console.error('Error deleting item:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Could not delete item' }),
        };
    }
};

// Original hello function (can be removed later if not needed)
module.exports.hello = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: 'Go Serverless v3! Your function executed successfully!',
        input: event,
      },
      null,
      2
    ),
  };
};

module.exports.snsListener = async (event) => {
  console.log('SNS Event Received:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    const message = JSON.parse(record.Sns.Message);
    console.log('Processed SNS message:', message);
    // Here you would typically process the message, e.g., update another database, send email, etc.
  }

  return { statusCode: 200 };
};