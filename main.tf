locals {
  entries = flatten([
    for client in var.clients : [
      for entry in coalesce(client.entries, []) : {
        key = "${client.name}/${entry.name}"
        value = {
          client_rn = "clgrp-${client.name}"
          ip        = entry.ip
          name      = entry.name
        }
      }
    ]
  ])
}

resource "aci_rest" "snmpPol" {
  dn         = "uni/fabric/snmppol-${var.name}"
  class_name = "snmpPol"
  content = {
    name    = var.name
    adminSt = var.admin_state == true ? "enabled" : "disabled"
    loc     = var.location
    contact = var.contact
  }
}

resource "aci_rest" "snmpUserP" {
  for_each   = { for user in var.users : user.name => user }
  dn         = "${aci_rest.snmpPol.dn}/user-${each.value.name}"
  class_name = "snmpUserP"
  content = {
    name     = each.value.name
    privType = each.value.privacy_type != null ? each.value.privacy_type : "none"
    privKey  = each.value.privacy_type != null && each.value.privacy_type != "none" ? each.value.privacy_key : null
    authType = each.value.authorization_type != null ? each.value.authorization_type : "hmac-md5-96"
    authKey  = each.value.authorization_key != null ? each.value.authorization_key : ""
  }

  lifecycle {
    ignore_changes = [content["privKey"], content["authKey"]]
  }
}

resource "aci_rest" "snmpCommunityP" {
  for_each   = toset(var.communities)
  dn         = "${aci_rest.snmpPol.dn}/community-${each.value}"
  class_name = "snmpCommunityP"
  content = {
    name = each.value
  }
}

resource "aci_rest" "snmpTrapFwdServerP" {
  for_each   = { for trap in var.trap_forwarders : trap.ip => trap }
  dn         = "${aci_rest.snmpPol.dn}/trapfwdserver-[${each.value.ip}]"
  class_name = "snmpTrapFwdServerP"
  content = {
    addr = each.value.ip
    port = each.value.port != null ? each.value.port : 162
  }
}

resource "aci_rest" "snmpClientGrpP" {
  for_each   = { for client in var.clients : client.name => client }
  dn         = "${aci_rest.snmpPol.dn}/clgrp-${each.value.name}"
  class_name = "snmpClientGrpP"
  content = {
    name = each.value.name
  }
}

resource "aci_rest" "snmpRsEpg" {
  for_each   = { for client in var.clients : client.name => client if client.mgmt_epg_name != null }
  dn         = "${aci_rest.snmpClientGrpP[each.value.name].dn}/rsepg"
  class_name = "snmpRsEpg"
  content = {
    tDn = each.value.mgmt_epg_type == "oob" ? "uni/tn-mgmt/mgmtp-default/oob-${each.value.mgmt_epg_name}" : "uni/tn-mgmt/mgmtp-default/inb-${each.value.mgmt_epg_name}"
  }
}

resource "aci_rest" "snmpClientP" {
  for_each   = { for entry in local.entries : entry.key => entry.value }
  dn         = "${aci_rest.snmpPol.dn}/${each.value.client_rn}/client-[${each.value.ip}]"
  class_name = "snmpClientP"
  content = {
    addr = each.value.ip
    name = each.value.name
  }
}
