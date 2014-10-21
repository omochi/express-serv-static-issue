var path = require("path");
var express = require("express");

var repoDir = path.normalize(__dirname)

var expressApp = express();
expressApp.use("/static", express.static(repoDir + "/static"));
var httpServer = expressApp.listen(3001, function() {
	console.log("Listening on port %d", httpServer.address().port);
});
