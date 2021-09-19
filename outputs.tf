output "dn" {
  value       = aci_rest.snmpPol.id
  description = "Distinguished name of `snmpPol` object."
}

output "name" {
  value       = aci_rest.snmpPol.content.name
  description = "SNMP policy name."
}
