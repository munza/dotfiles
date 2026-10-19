-- Validation and completion for package.json, tsconfig.json and friends.
return {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
