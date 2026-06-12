module.exports = {
  env: {
    es2020: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2020,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    // نُبقي فحوص المنطق مفعّلة، لكن نخفف قواعد التنسيق الحساسة
    // لأن الملف يحتوي حالياً على نصوص عربية قد تتضرر ترميزياً أثناء النقل بين البيئات.
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    "linebreak-style": 0,
    "max-len": 0,
    "no-irregular-whitespace": 0,
    "no-trailing-spaces": 0,
    "object-curly-spacing": 0,
    "indent": ["error", 2],
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
