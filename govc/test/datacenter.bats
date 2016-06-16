#!/usr/bin/env bats

load test_helper

@test "datacenter.info" {
    dc=$(govc ls -t Datacenter / | head -n1)
    run govc datacenter.info "$dc"
    assert_success

    run govc datacenter.info -json "$dc"
    assert_success

    run govc datacenter.info /enoent
    assert_failure
}

@test "create and destroy datacenters" {
  vcsim_env

  dcs=($(new_id) $(new_id))
  run govc datacenter.create "${dcs[@]}"
  assert_success

  for dc in ${dcs[*]}; do
    run govc ls "/$dc"
    assert_success
    # /<datacenter>/{vm,network,host,datastore}
    [ ${#lines[@]} -eq 4 ]

    run govc datacenter.info "/$dc"
    assert_success
  done

  run govc datacenter.destroy "${dcs[@]}"
  assert_success

  for dc in ${dcs[*]}; do
    run govc ls "/$dc"
    assert_success
    [ ${#lines[@]} -eq 0 ]
  done
}

@test "destroy datacenter using glob" {
  vcsim_env
  unset GOVC_DATACENTER GOVC_DATASTORE

  folder=$(new_id)
  dcs=($(new_id) $(new_id))

  run govc folder.create "$folder"
  assert_success

  run govc datacenter.create -folder "$folder" "${dcs[@]}"
  assert_success

  run govc datacenter.destroy "$folder/*"
  assert_success

  for dc in ${dcs[*]}; do
    run govc ls "/$dc"
    assert_success
    [ ${#lines[@]} -eq 0 ]
  done

  run govc folder.destroy "$folder"
  assert_success
}

@test "destroy datacenter that does not exist" {
  vcsim_env

  run govc datacenter.destroy "/enoent"
  assert_failure
}

@test "fails when datacenter name not specified" {
  run govc datacenter.create
  assert_failure

  run govc datacenter.destroy
  assert_failure
}

@test "datacenter commands fail against ESX" {
  run govc datacenter.create something
  assert_failure
  assert_output "govc: ServerFaultCode: The operation is not supported on the object."

  run govc datacenter.destroy ha-datacenter
  assert_failure
  assert_output "govc: The operation is not supported on the object."
}
