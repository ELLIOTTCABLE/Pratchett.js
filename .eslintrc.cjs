/* eslint-env node */

module.exports = {
   root: true,
   plugins: ["@typescript-eslint", "import", "unicorn", "jest"],
   settings: {
      "import/parsers": {
         "@typescript-eslint/parser": [".ts", ".tsx"],
      },
   },
   extends: [
      "eslint:recommended",
      "plugin:eslint-comments/recommended",
      "plugin:node/recommended",
      "plugin:import/recommended",
      "plugin:unicorn/recommended",
      "prettier",
   ],
   rules: {
      "node/shebang": 0,
      "node/no-missing-import": 0,
   },
   overrides: [
      {
         files: ["*.ts", "*.tsx"],
         parser: "@typescript-eslint/parser",
         parserOptions: {
            tsconfigRootDir: __dirname,
            project: ["./tsconfig.json"],
         },
         plugins: ["@typescript-eslint", "import", "unicorn", "jest"],
         extends: [
            "eslint:recommended",
            "plugin:@typescript-eslint/recommended",
            "plugin:@typescript-eslint/recommended-requiring-type-checking",
            "plugin:eslint-comments/recommended",
            "plugin:node/recommended",
            "plugin:import/recommended",
            "plugin:import/typescript",
            "plugin:unicorn/recommended",
            "prettier",
         ],
         rules: {
            "node/no-unsupported-features/es-syntax": 0,
            "node/no-missing-import": 0,

            "no-empty-function": "off",
            "@typescript-eslint/no-empty-function": ["error"],

            // Under minor testing, Array#concat is significantly faster than [...double, ...spread]
            "unicorn/prefer-spread": 1,

            // I intend to transform with Babel or similar
            "node/no-unsupported-features/es-builtins": 1,

            // This seems super-broken, tbh. It catches all sorts of completely normal
            // `map()` calls, like, wtf?
            "unicorn/no-array-callback-reference": 0,
         },
      },
      {
         files: ["*.tests.ts", "*.tests.tsx"],
         parserOptions: {
            tsconfigRootDir: __dirname,
            project: ["./Test/tsconfig.json"],
         },
         plugins: ["@typescript-eslint", "import", "unicorn", "jest"],
         settings: {
            node: {
               allowModules: ["chai"],
            },
         },
         extends: [
            "eslint:recommended",
            "plugin:@typescript-eslint/recommended",
            "plugin:@typescript-eslint/recommended-requiring-type-checking",
            "plugin:eslint-comments/recommended",
            "plugin:import/recommended",
            "plugin:import/typescript",
            // "plugin:jest/recommended",
            // "plugin:jest/style",
            "plugin:unicorn/recommended",
            "prettier",
         ],
         rules: {
            "@typescript-eslint/unbound-method": "error",

            // It is idiomatic to nest test-describe-blocks deeply
            "unicorn/consistent-function-scoping": 0,
         },
      },
   ],
}
