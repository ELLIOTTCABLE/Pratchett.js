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
         },
      },
      {
         files: ["*.tests.ts", "*.tests.tsx"],
         plugins: ["@typescript-eslint", "import", "unicorn", "jest"],
         extends: [
            "eslint:recommended",
            "plugin:@typescript-eslint/recommended",
            "plugin:@typescript-eslint/recommended-requiring-type-checking",
            "plugin:eslint-comments/recommended",
            "plugin:node/recommended",
            "plugin:import/recommended",
            "plugin:import/typescript",
            "plugin:jest/recommended",
            "plugin:jest/style",
            "plugin:unicorn/recommended",
            "prettier",
         ],
         rules: {
            "@typescript-eslint/unbound-method": "error",
         },
      },
   ],
}
