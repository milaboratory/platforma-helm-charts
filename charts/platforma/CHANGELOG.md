# Changelog
All notable changes to this project will be documented in this file.
## [v2.2.1] - 2026-01-15
### Features

- Add support for multi-hosts for ingress ([`8b6105f`](https://github.com/milaboratory/platforma-helm-charts/commit/8b6105fe199d49fc8ee391039a2b1fefdee410f3))
### MILAB-5304

- Give platforma 15 min before becoming ready (long bootstrap) ([`dd55d2c`](https://github.com/milaboratory/platforma-helm-charts/commit/dd55d2c79f026a4b95b6eff0528c9557b66e981b))
### Miscellaneous Tasks

- Update tls checking logic based on suggestions ([`714d044`](https://github.com/milaboratory/platforma-helm-charts/commit/714d044ae3713ea59f3739f3ea5487810e53ab1f))

## [v2.2.0] - 2025-11-26
### Miscellaneous Tasks

- Pass ldap search password as env variable ([`e122812`](https://github.com/milaboratory/platforma-helm-charts/commit/e122812166708028b97535477664aeb776889cd8))

## [v2.1.9] - 2025-11-26
### Miscellaneous Tasks

- Fail if secreRef is enabled by name is empty ([`477698a`](https://github.com/milaboratory/platforma-helm-charts/commit/477698aceede30fad5dbafc49b00d5e3f77818d6))
- Add ldap user search password ([`ef374fa`](https://github.com/milaboratory/platforma-helm-charts/commit/ef374fa511e635a0a91737d9243ca60cd6c255f6))

## [v2.1.8] - 2025-11-26
### Miscellaneous Tasks

- Fix tests ([`473ec8f`](https://github.com/milaboratory/platforma-helm-charts/commit/473ec8f409ed19339d8c457f3557da4f9633e377))
- Fix values schema ([`fdc4d97`](https://github.com/milaboratory/platforma-helm-charts/commit/fdc4d97e0f492d7698a1cceefb13a83242fe3c4d))

## [v2.1.7] - 2025-11-24
### Miscellaneous Tasks

- Don't force ingress settings if fs is primary storage ([`af75d64`](https://github.com/milaboratory/platforma-helm-charts/commit/af75d645ce56ca21c8def7dbe7b49ab7810ba48a))
- Fix typo ([`fce11dd`](https://github.com/milaboratory/platforma-helm-charts/commit/fce11ddc7cf15551314bde3eb559a8f7d18971fe))
- Enable fs storage buy defualt ([`813a210`](https://github.com/milaboratory/platforma-helm-charts/commit/813a2103f22b31c2589a71f436f8629dd5b9c0e8))
- Add additional options to pass rootCas ([`a99895d`](https://github.com/milaboratory/platforma-helm-charts/commit/a99895d1c657b919674d4a93a42bd8dd41f2ff68))
- Update README.md ([`bb0fe6c`](https://github.com/milaboratory/platforma-helm-charts/commit/bb0fe6c1d63d21f976fee7c273c090634a2a23b4))
- Update pl version and update defaults for platforma ([`220fb99`](https://github.com/milaboratory/platforma-helm-charts/commit/220fb9942f483e7abbbe66f59fc87e16c25fbc7f))

## [v2.1.6] - 2025-11-17
### Bug Fixes

- Wrong template ([`86b9fd1`](https://github.com/milaboratory/platforma-helm-charts/commit/86b9fd185fc64a76fea512366eea4dfef47ca739))
### Miscellaneous Tasks

- Change ladp settings update documentation ([`acafc92`](https://github.com/milaboratory/platforma-helm-charts/commit/acafc92504549241578d4d4fcb9f14837e322c4b))

## [v2.1.5] - 2025-11-14
### Miscellaneous Tasks

- Add job google batch template example ([`1476837`](https://github.com/milaboratory/platforma-helm-charts/commit/14768375cbb8b3b9e579493ab63d3f30148b5ae2))
- Add google batch job template ([`d6a00b2`](https://github.com/milaboratory/platforma-helm-charts/commit/d6a00b2b7edf5d7346d4c04c1d511c2c2fc86b4e))

## [v2.1.4] - 2025-10-24
### Miscellaneous Tasks

- Fix container port ([`49285d4`](https://github.com/milaboratory/platforma-helm-charts/commit/49285d4efe8db98b8d581fda6ce55a4cc7dfa0c4))

## [v2.1.3] - 2025-10-17
### Miscellaneous Tasks

- Remove default affinity ([`20a70f0`](https://github.com/milaboratory/platforma-helm-charts/commit/20a70f0814da0f9aeebf1ff53d464c1cc4cfc7a1))

## [v2.1.2] - 2025-10-17
### Miscellaneous Tasks

- Sync with gsk settings ([`6c04d99`](https://github.com/milaboratory/platforma-helm-charts/commit/6c04d99be8fcb5fe8688a826002db3a4a465bf04))
- Add docker privileged ([`4d2baf1`](https://github.com/milaboratory/platforma-helm-charts/commit/4d2baf15f690e43f4dc34d3f98167610429dd3d2))
- Add rootless docker configuration ([`cca0a00`](https://github.com/milaboratory/platforma-helm-charts/commit/cca0a00f6dc852f5b619b5a07151952744f72e11))

## [v2.1.1] - 2025-10-02
### Features

- PodMonitoring [draft] ([`58a972b`](https://github.com/milaboratory/platforma-helm-charts/commit/58a972ba4080eb746cf8925a098a9d539b38a55a))
### Ref

- Disable by default ([`5958a30`](https://github.com/milaboratory/platforma-helm-charts/commit/5958a309be453c4a18ac8028afbac4e34c27a6c9))
- Drop alerts ([`0db2e3b`](https://github.com/milaboratory/platforma-helm-charts/commit/0db2e3b0f5ac0e7475664a00bf0b524833adf224))
- Cleanup unused ([`c8c637e`](https://github.com/milaboratory/platforma-helm-charts/commit/c8c637e4e8c086f550406c161015e5403e5d84fd))
- Clear unused ([`c2d2c14`](https://github.com/milaboratory/platforma-helm-charts/commit/c2d2c144d048abaedc79122df899e42c68ec6edd))
- Rename file ([`0c6519d`](https://github.com/milaboratory/platforma-helm-charts/commit/0c6519da9f5f2697128e050a961fd7d9e8353b44))

## [v2.1.0] - 2025-09-24
### Documentation

- Update Documentation ([`7255b70`](https://github.com/milaboratory/platforma-helm-charts/commit/7255b706fa6ac16c787939d7015805fd656be98e))
### MILAB-3890

- Initial dind side container implementation ([`d831e17`](https://github.com/milaboratory/platforma-helm-charts/commit/d831e17ceef84ca0f828d335fccdb10623fa7ded))
### Bugfix

- Do not require secretRef to be defined when library is disabled ([`a53ffce`](https://github.com/milaboratory/platforma-helm-charts/commit/a53ffcea5138e46027dc25ccec3f37fd2512b378))

## [v2.0.6] - 2025-08-12
### Bug Fixes

- Use gpg legacy format ([`5cadeac`](https://github.com/milaboratory/platforma-helm-charts/commit/5cadeaca41e7a90ae2a7da4c9fdac2acdcb115b4))
- Indentation in values ([`24577b6`](https://github.com/milaboratory/platforma-helm-charts/commit/24577b6215f0ebcf1876e3973d05de77c232d278))
- Typo ([`f4b016b`](https://github.com/milaboratory/platforma-helm-charts/commit/f4b016bb95f7dae37825524e16ade54a7a462b19))
- Pass keyring ([`940fff2`](https://github.com/milaboratory/platforma-helm-charts/commit/940fff27f00c22969bc624b611c4d334f86497cf))
- Simplify the workflow ([`dcab625`](https://github.com/milaboratory/platforma-helm-charts/commit/dcab6259464ce38d89e95d710569b0df4536d4b9))
- Set correct output ([`32d4cc2`](https://github.com/milaboratory/platforma-helm-charts/commit/32d4cc218ec80c772144ebb10d2f60435581c70c))
- Use legacy secret keyring for Helm signing ([`717f627`](https://github.com/milaboratory/platforma-helm-charts/commit/717f627a6ce5f2a5a6cf465e008c2bcc62ef545b))
- Use legacy GPG pubring for Helm signing to resolve OpenPGP error ([`230546d`](https://github.com/milaboratory/platforma-helm-charts/commit/230546d43e41881e3bd8dfc9172b6f578aa9b83a))
### Documentation

- Add FS primary storage guidance in NOTES.txt ([`b3cc680`](https://github.com/milaboratory/platforma-helm-charts/commit/b3cc6808b9206ac89cf4aa8245dbc3546aba9f82))
### Miscellaneous Tasks

- Update gpg key ([`246da58`](https://github.com/milaboratory/platforma-helm-charts/commit/246da5871ac06689ea230517f99972ae9438b453))

## [v2.0.5] - 2025-08-08
### Miscellaneous Tasks

- Expand values.schema.json coverage; no template changes ([`e7f5aaa`](https://github.com/milaboratory/platforma-helm-charts/commit/e7f5aaae6380af93293b27df3ea7d0bda5c24a3a))

## [v2.0.4] - 2025-08-08
### Miscellaneous Tasks

- Add helm chart logo ([`e80d5ed`](https://github.com/milaboratory/platforma-helm-charts/commit/e80d5edd060d520d973d55c85539e1c43ac24ad7))

## [v2.0.3] - 2025-08-08
### Bug Fixes

- Cliff.tpml ([`93e6f2a`](https://github.com/milaboratory/platforma-helm-charts/commit/93e6f2a1124259405601880484bb90d01eb73752))
### Miscellaneous Tasks

- Update validation schema ([`46f4c8e`](https://github.com/milaboratory/platforma-helm-charts/commit/46f4c8ea88d5000d835f9ed201e4adc18a91c6d6))

