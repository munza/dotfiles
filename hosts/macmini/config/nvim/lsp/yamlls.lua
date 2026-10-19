-- Schemas for GitHub workflows, compose files and the like, from SchemaStore
-- rather than the server's own download.
return {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
