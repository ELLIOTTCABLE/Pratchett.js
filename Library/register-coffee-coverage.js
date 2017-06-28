var package        = require('../package.json')
  , path           = require('path')
  , coffeeCoverage = require('coffee-coverage')

var projectRoot    = path.resolve(__dirname, "..")
  , coverageDir    = path.join(projectRoot, package.config.dirs.coverage)
  , coverageVar    = coffeeCoverage.findIstanbulVariable()
  , writeOnExit    = (coverageVar == null) ? path.join(coverageDir, 'coverage-coffee.json') : null

coffeeCoverage.register({
   instrumentor: 'istanbul'

 , basePath: projectRoot
 , exclude: [
      '/.git'
    , '/node_modules'
    , package.config.dirs.test + '/'
   ]

 , coverageVar: coverageVar
 , writeOnExit: writeOnExit

 , initAll: true
});
