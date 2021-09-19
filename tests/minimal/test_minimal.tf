terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "netascode/aci"
      version = ">=0.2.0"
    }
  }
}

module "main" {
  source = "../.."

  name = "SNMP1"
}

data "aci_rest" "snmpPol" {
  dn = "uni/fabric/snmppol-${module.main.name}"

  depends_on = [module.main]
}

resource "test_assertions" "snmpPol" {
  component = "snmpPol"

  equal "name" {
    description = "name"
    got         = data.aci_rest.snmpPol.content.name
    want        = module.main.name
  }
}
