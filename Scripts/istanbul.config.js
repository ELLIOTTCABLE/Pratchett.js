var package        = require('../package.json')
  , path           = require('path')

var projectRoot    = path.resolve(__dirname, "..")
  , coverageDir    = path.join(projectRoot, package.config.dirs.coverage)

module.exports = {

   instrumentation: {
      root: projectRoot
   }

 , reporting: {
      print: 'detail' // May not have any effecft outside of `cover`?
    , reports: [ 'lcovonly', 'html', 'text' ]
    , dir: coverageDir

    , watermarks: {
         statements: [40, 85]
       , lines:      [40, 85]
       , functions:  [40, 85]
       , branches:   [40, 85]
      }

    , 'report-config': {
         text: { maxCols: process.stdout.columns || 80 }
      }
   }

}
