# convert external data to JSON, a format that Terraform expects
require 'json'
data = {
  owner: "Packt"
}
puts data.to_json
