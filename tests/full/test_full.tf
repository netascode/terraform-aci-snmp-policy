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

  name        = "SNMP1"
  admin_state = true
  location    = "LOC"
  contact     = "CON"
  communities = ["COM1"]
  users = [{
    name               = "USER1"
    privacy_type       = "aes-128"
    privacy_key        = "ABCDEFGH"
    authorization_type = "hmac-sha1-96"
    authorization_key  = "ABCDEFGH"
  }]
  trap_forwarders = [{
    ip   = "1.1.1.1"
    port = 1162
  }]
  clients = [{
    name          = "CLIENT1"
    mgmt_epg      = "oob"
    mgmt_epg_name = "OOB1"
    entries = [{
      ip   = "10.1.1.1"
      name = "NMS1"
    }]
  }]
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

  equal "adminSt" {
    description = "adminSt"
    got         = data.aci_rest.snmpPol.content.adminSt
    want        = "enabled"
  }

  equal "loc" {
    description = "loc"
    got         = data.aci_rest.snmpPol.content.loc
    want        = "LOC"
  }

  equal "contact" {
    description = "contact"
    got         = data.aci_rest.snmpPol.content.contact
    want        = "CON"
  }
}

data "aci_rest" "snmpUserP" {
  dn = "${data.aci_rest.snmpPol.id}/user-USER1"

  depends_on = [module.main]
}

resource "test_assertions" "snmpUserP" {
  component = "snmpUserP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.snmpUserP.content.name
    want        = "USER1"
  }

  equal "privType" {
    description = "privType"
    got         = data.aci_rest.snmpUserP.content.privType
    want        = "aes-128"
  }

  equal "authType" {
    description = "authType"
    got         = data.aci_rest.snmpUserP.content.authType
    want        = "hmac-sha1-96"
  }
}

data "aci_rest" "snmpCommunityP" {
  dn = "${data.aci_rest.snmpPol.id}/community-COM1"

  depends_on = [module.main]
}

resource "test_assertions" "snmpCommunityP" {
  component = "snmpCommunityP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.snmpCommunityP.content.name
    want        = "COM1"
  }
}

data "aci_rest" "snmpTrapFwdServerP" {
  dn = "${data.aci_rest.snmpPol.id}/trapfwdserver-[1.1.1.1]"

  depends_on = [module.main]
}

resource "test_assertions" "snmpTrapFwdServerP" {
  component = "snmpTrapFwdServerP"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.snmpTrapFwdServerP.content.addr
    want        = "1.1.1.1"
  }

  equal "port" {
    description = "port"
    got         = data.aci_rest.snmpTrapFwdServerP.content.port
    want        = "1162"
  }
}

data "aci_rest" "snmpClientGrpP" {
  dn = "${data.aci_rest.snmpPol.id}/clgrp-CLIENT1"

  depends_on = [module.main]
}

resource "test_assertions" "snmpClientGrpP" {
  component = "snmpClientGrpP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.snmpClientGrpP.content.name
    want        = "CLIENT1"
  }
}

data "aci_rest" "snmpRsEpg" {
  dn = "${data.aci_rest.snmpClientGrpP.id}/rsepg"

  depends_on = [module.main]
}

resource "test_assertions" "snmpRsEpg" {
  component = "snmpRsEpg"

  equal "tDn" {
    description = "tDn"
    got         = data.aci_rest.snmpRsEpg.content.tDn
    want        = "uni/tn-mgmt/mgmtp-default/oob-OOB1"
  }
}

data "aci_rest" "snmpClientP" {
  dn = "${data.aci_rest.snmpClientGrpP.id}/client-[10.1.1.1]"

  depends_on = [module.main]
}

resource "test_assertions" "snmpClientP" {
  component = "snmpClientP"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.snmpClientP.content.addr
    want        = "10.1.1.1"
  }

  equal "name" {
    description = "name"
    got         = data.aci_rest.snmpClientP.content.name
    want        = "NMS1"
  }
}
