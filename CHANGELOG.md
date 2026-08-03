# Changelog

## [0.3.0](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/compare/v0.2.1...v0.3.0) (2026-08-03)


### Features

* made bastion as optional to integrate with autoglue ([6325f9f](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/6325f9f2aecbb79621fc3fc7e4c97cdfc12e7cc4))
* move autoglue/proxmox action under separate repo ([b2d4cc1](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/b2d4cc15e94a919acbd95f88bdb4e0da05f562b7))


### Bug Fixes

* add available_nodes ([cb19e6c](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/cb19e6c6404a52d92e86c040d37d0c15ecdf2f4b))
* add e2e-test for gluekube-autoglue ([5d18fbf](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/5d18fbf66cc908530fd23ebe0aa3fbbdc6ea79b4))
* add exit node ([d44d7b4](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/d44d7b4500d98d1aa8a6f21517c34730fefea70d))
* added autoglue nuke ([ce7f686](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/ce7f686ba3893b9a439684855d7a2a23ce77a4f6))
* added nuke for proxmox ([16b5314](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/16b5314ea8d88a317fa15f7a8f6ff5b3f8d2d46f))
* added schedule ([8547f0f](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/8547f0f250619e9f55f828bbfabce2255bd54bdc))
* changed ref to main ([4bf05b6](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/4bf05b6df338bfd0f8ae88613bcbdffc15a6d093))
* continue on error on tofu destroy ([b22f6f7](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/b22f6f7880e05554d33917eabcb8e28f144673a3))
* dns ([d43695c](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/d43695c95d32a03587154a4bc601edd64efba4be))
* e2e ([1e6b791](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/1e6b7912613c3b8fe127cd5359f821aaeeb8cd4c))
* e2e-test changed example variables.tf ([ab8919c](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/ab8919c219676144608a96b5053dd3098c4e37ce))
* gluekube tag ([512ed22](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/512ed222666bea6b0e3df76ca1ac347c31aa5157))
* gluekube_tag ([729fbb9](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/729fbb938165c06c3ec27453e2370bbbb262629b))
* jq parsing error ([a117442](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/a117442d1acdecf0b964e2792fcd6d7779657cc8))
* piepline and cloud-init ([cabddca](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/cabddca6bd9adc4c6c6effc5cfcaef41c65a665c))
* pipeline ([bfff7f7](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/bfff7f7b0e97df72ad0532f2471b0731f8db0c9f))
* provider creds ([87d7559](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/87d75595dcf5817aa8b55657049a7deca7b5c1d8))
* remove ssh pass auth ([0ac302c](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/0ac302c83501515ea21d893bb36d6ed9ae74f824))
* removed exit node ([9a7e72f](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/9a7e72f5835625058d9b7fdd154ad6fcf1df9215))
* revert back exit node ([355a821](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/355a821c4b961c16cbc8d464f12d97f525720d0a))
* test ([9ec5e14](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/9ec5e149331d4ff66707d2f74a4c3a40086ec029))
* test-apply ([0550d75](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/0550d75c24132ff750c24bd43de606be3fc10020))
* test-apply with cluster healthcheck ([940a0ab](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/940a0ab0731265e14237a09bbf799fc64eb0cad3))
* variables.tf ([8c4bdf1](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/8c4bdf159d9730c2e10d56436642f67229b2b6b4))
* workflow ([aeb36aa](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/aeb36aaf2345683b6b6d1dd9076dc06778654532))
* workflow ([7aea3de](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/7aea3de4523269cc85711f5d46bf8dd076dd35ad))
* workflow to always run apply ([350a33c](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/350a33cec06476326c773b12b3a737ff4021aa55))


### Miscellaneous Chores

* add Apache-2.0 LICENSE ([#30](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/issues/30)) ([20b9031](https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox/commit/20b903160a392177e10dbd9e9e467aba869b8f95))
