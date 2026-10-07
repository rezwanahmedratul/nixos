{ pkgs, ... }:

{
  security.wrappers.gpu-screen-recorder = {
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
  };

  security.wrappers.gsr-kms-server = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
  };
}