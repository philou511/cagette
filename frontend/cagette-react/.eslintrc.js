module.exports =  {
  env: {
    browser: true,
  },
  parser:  '@typescript-eslint/parser',
  parserOptions:  {
    ecmaVersion:  2018,  
    sourceType:  'module',
    ecmaFeatures:  {
      jsx:  true, 
    }
  },
  extends:  [
    'airbnb',
    'plugin:react/recommended',
    'plugin:@typescript-eslint/recommended',  
    'prettier/@typescript-eslint',
    'plugin:prettier/recommended',
    'plugin:import/typescript'
  ],
  rules:  {
    "no-underscore-dangle": "off",
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/explicit-member-accessibility": "off",
    "react/jsx-props-no-spreading": "off",
    "react/jsx-filename-extension": [1, { "extensions": [".js", ".jsx", '.ts', '.tsx'] }],
    "jsx-a11y/anchor-is-valid": [
      "error",
      {
        "components": ["Link"],
        "specialLink": ["hrefLeft", "hrefRight"],
        "aspects": ["invalidHref", "preferButton"]
      }
    ],
    "import/extensions": [
      "error",
      "ignorePackages", 
      {
        "js": "never",
        "jsx": "never",
        "json": "never",
        "ts": "never",
        "tsx": "never"
      }
    ],
    "@typescript-eslint/no-unused-vars": ["warn", {
      "args": "after-used",
      "ignoreRestSiblings": true
    }]
  },
  settings:  {
    react:  {
      version:  'detect'
    }
  },
};