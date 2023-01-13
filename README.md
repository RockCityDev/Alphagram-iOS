## About

Alphagram, the Web3 Telegram.

Creates a secure 3rd party Web3 Telegram for worldwide users！ 

## Features - Provides More Convenience

1. Comfortable - Incognito Mode, The other party can't see the message read double checkmark.
2. Fast - Unlimited Pinned Messages, Help you find important messages quickly.
3. Instantly - Translate every message with one click, Help you manage the international communication and information.
4. Helpful - Practical tools, Scan the code to add friends/Easy to clear up storage.
5. Safe - Crypto Wallet, Fast Web3 Asset Transaction.
6. Auto-sync - NFT Profile Verification, Give you immersive Web3 experience.
7. Advanced - Crypto Transfer, Transactions will be done in a chat box.
8. Statistics - Web3 Profile, Check your crypto public data easily.

### Web3

1. Web3Swift https://github.com/web3swift-team/web3swift
2. TSS Wallet https://docs.particle.network/
3. Wallet-Connect https://docs.walletconnect.com/1.0/
4. OpenSeaAPI https://docs.opensea.io/reference/api-overview

# Telegram iOS Source Code Compilation Guide

We welcome all developers to use our API and source code to create applications on our platform.
There are several things we require from **all developers** for the moment.

# Creating your Telegram Application

1. [**Obtain your own api_id**](https://core.telegram.org/api/obtaining_api_id) for your application.
2. Please **do not** use the name Telegram for your app — or make sure your users understand that it is unofficial.
3. Kindly **do not** use our standard logo (white paper plane in a blue circle) as your app's logo.
3. Please study our [**security guidelines**](https://core.telegram.org/mtproto/security_guidelines) and take good care of your users' data and privacy.
4. Please remember to publish **your** code too in order to comply with the licences.

# Compilation Guide

1. Install Xcode (directly from https://developer.apple.com/download/more or using the App Store).
2. Clone the project from GitHub:

```
git clone --recursive -j8 https://github.com/alphagramfortg/Alphagram-iOS
```

3. Adjust configuration parameters

```
mkdir bazel-dist & mkdir telegram-configuration & mkdir telegram-bazel-cache
mkdir -p $HOME/telegram-configuration
cp -R build-system/example-configuration/* $HOME/telegram-configuration/
```

- Modify the values in `variables.bzl`
- Replace the provisioning profiles in `provisioning` with valid files

4. (Optional) Create a build cache directory to speed up rebuilds

```
mkdir -p "$HOME/telegram-bazel-cache"
```

5. Build the app

```
python3 build-system/Make/Make.py \
    --bazel="$HOME/bazel-dist/bazel" \
    --cacheDir="$HOME/telegram-bazel-cache" \
    build \
    --configurationPath="$HOME/telegram-configuration" \
    --buildNumber=100001 \
    --configuration=release_universal
```

6. (Optional) Generate an Xcode project

```
python3 build-system/Make/Make.py \
    --bazel="$HOME/bazel-dist/bazel" \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath="$HOME/telegram-configuration" \
    --disableExtensions
```

It is possible to generate a project that does not require any codesigning certificates to be installed: add `--disableProvisioningProfiles` flag:
```
python3 build-system/Make/Make.py \
    --bazel="$HOME/bazel-dist/bazel" \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath="$HOME/telegram-configuration" \
    --disableExtensions \
    --disableProvisioningProfiles
```


Tip: use `--disableExtensions` when developing to speed up development by not building application extensions and the WatchOS app.


# Tips

Bazel is used to build the app. To simplify the development setup a helper script is provided (`build-system/Make/Make.py`). See help:

```
python3 build-system/Make/Make.py --help
python3 build-system/Make/Make.py build --help
python3 build-system/Make/Make.py generateProject --help
```

Bazel is automatically downloaded when running Make.py for the first time. If you wish to use your own build of Bazel, pass `--bazel=path-to-bazel`. If your Bazel version differs from that in `versions.json`, you may use `--overrideBazelVersion` to skip the version check.

Each release is built using specific Xcode and Bazel versions (see `versions.json`). The helper script checks the versions of installed software and reports an error if they don't match the ones specified in `versions.json`. There are flags that allow to bypass these checks:

```
python3 build-system/Make/Make.py --overrideBazelVersion build ... # Don't check the version of Bazel
python3 build-system/Make/Make.py --overrideXcodeVersion build ... # Don't check the version of Xcode
```
