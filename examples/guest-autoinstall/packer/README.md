# Packer reviewed-skeleton contract

The checked-in `vsphere-iso` files are **reviewed skeletons**, not runnable
end-to-end builds. They demonstrate a vCenter-oriented builder boundary and
safe variable separation, while deliberately omitting unattended-media wiring
that depends on the chosen operating-system variant and local secret handling.

Do not point these files at free or standalone ESXi and do not run `packer
build` directly from the committed examples.

## Safe local workflow

1. Copy the required template and answer/seed files into a private working
   directory.
2. Attach unattended media explicitly:
   - Ubuntu: use `cd_files` for `user-data` and `meta-data` with `cd_label =
     "cidata"`, or use another reviewed NoCloud transport.
   - Windows: attach an `Autounattend.xml` through `cd_content`, `cd_files`, a
     secondary ISO, or a floppy, and ensure it creates/configures the account
     and communicator selected by the template.
3. Create a non-committed local `.pkrvars.hcl` file.
4. Run `scripts/validate-packer-contract.sh --vars /path/to/local.pkrvars.hcl`.
5. Run `packer init`, `packer fmt -check`, and `packer validate` in the private
   working directory.
6. Review the exact target, destructive disk behaviour, network, datastore,
   answer file, communicator, and rollback before an approved build.

The static CI check fails if a committed template stops declaring this
reviewed-skeleton boundary or starts implying standalone ESXi support.
