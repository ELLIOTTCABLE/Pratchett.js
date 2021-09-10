const { ESLint } = require("eslint"),
   pjson = require("./package.json"),
   path = require("path")

const projectRoot = path.resolve(__dirname),
   docsDir = path.join(projectRoot, pjson.config.dirs.documentation)

// Handling .eslintignore; see:
//    <https://github.com/okonet/lint-staged/tree/0ef25e81a150ae59749d28565b305c97ec932baa#how-can-i-ignore-files-from-eslintignore>
const removeIgnoredFiles = async (files) => {
   const eslint = new ESLint()
   const isIgnored = await Promise.all(
      files.map((file) => {
         return eslint.isPathIgnored(file)
      }),
   )
   const filteredFiles = files.filter((_, i) => !isIgnored[i])
   return filteredFiles.join(" ")
}

module.exports = {
   "*": "prettier --ignore-unknown --write",

   "*.{ts,js,mjs,cjs}": async (files) => {
      const filesToLint = await removeIgnoredFiles(files)
      return [`eslint --cache --max-warnings=0 ${filesToLint}`]
   },

   "*.ts": () => [
      "tsc -p tsconfig.json --noEmit",
      "typedoc --logLevel Warn",
      `git add "${docsDir}/assets" "${docsDir}/"*.html`,
   ],

   "{Source,Test}/*.{ts,js,mjs,cjs,coffee}":
      "cross-env PRE_COMMIT=true npm --loglevel=silent run test --",

   "Scripts/**/*.sh": "shellcheck",
}
