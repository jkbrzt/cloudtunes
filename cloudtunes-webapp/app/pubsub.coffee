Backbone = require 'backbone'
_ = require 'underscore'


pubsub = _.extend {}, Backbone.Events
pubsub.subscribe = pubsub.on
pubsub.unsubscribe = pubsub.off
pubsub.publish = pubsub.trigger

module.exports = pubsub
