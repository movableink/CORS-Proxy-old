'use strict';

module.exports = function(data) {
  data.date = new Date().toISOString();
  console.log(JSON.stringify(data));
};
