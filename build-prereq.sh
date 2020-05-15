#!/bin/bash
set -euo pipefail

# Copyright 2017 Google LLC.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

echo ========== Load config settings.

source settings.sh

################################################################################
# Misc. setup
################################################################################

note_build_stage "Install the runtime packages"

./run-prereq.sh

################################################################################
# bazel
################################################################################

note_build_stage "Install bazel"

function ensure_wanted_bazel_version {
  local wanted_bazel_version=$1
  rm -rf ~/bazel
  mkdir ~/bazel

  if
    v=$(bazel --bazelrc=/dev/null --nomaster_bazelrc version) &&
    echo "$v" | awk -v b="$wanted_bazel_version" '/Build label/ { exit ($3 != b)}'
  then
    echo "Bazel ${wanted_bazel_version} already installed on the machine, not reinstalling"
  else
    pushd ~/bazel
    curl -L -O https://github.com/bazelbuild/bazel/releases/download/"${wanted_bazel_version}"/bazel-"${wanted_bazel_version}"-installer-linux-x86_64.sh
    chmod +x bazel-*.sh
    ./bazel-"${wanted_bazel_version}"-installer-linux-x86_64.sh --user > /dev/null
    rm bazel-"${wanted_bazel_version}"-installer-linux-x86_64.sh
    popd
  fi
}

ensure_wanted_bazel_version "${DV_BAZEL_VERSION}"

################################################################################
# CLIF
################################################################################

note_build_stage "Install CLIF binary"

if [[ -e /usr/local/clif/bin/pyclif ]];
then
  echo "CLIF already installed."
# else
#   # Figure out which linux installation we are on to fetch an appropriate
#   # version of the pre-built CLIF binary. Note that we only support now Ubuntu
#   # 14, 16, and 18.
#   case "$(lsb_release -d)" in
#     *Ubuntu*18.*.*) export DV_PLATFORM="ubuntu-18" ;;
#     *Ubuntu*16.*.*) export DV_PLATFORM="ubuntu-16" ;;
#     *Ubuntu*14.*.*) export DV_PLATFORM="ubuntu-14" ;;
#     *Debian*9.*)    export DV_PLATFORM="debian" ;;
#     *Debian*rodete) export DV_PLATFORM="debian" ;;
#     *) echo "CLIF is not installed on this machine and a prebuilt binary is not
# available for this platform. Please install CLIF at
# https://github.com/google/clif before continuing."
#     exit 1
#   esac

  # DV_PLATFORM=ubuntu-16

  # OSS_CLIF_CURL_ROOT="${DV_PACKAGE_CURL_PATH}/oss_clif_py3"
  # OSS_CLIF_PKG="oss_clif.${DV_PLATFORM}.latest.tgz"

  # if [[ ! -f "/tmp/${OSS_CLIF_PKG}" ]]; then
  #   curl "${OSS_CLIF_CURL_ROOT}/${OSS_CLIF_PKG}" > /tmp/${OSS_CLIF_PKG}
  # fi

  # (cd / && sudo tar xzf "/tmp/${OSS_CLIF_PKG}")
    # sudo ldconfig  # Reload shared libraries.

fi

################################################################################
# TensorFlow
################################################################################

note_build_stage "Download and configure TensorFlow sources"

if [[ ! -d ../tensorflow ]]; then
  note_build_stage "Cloning TensorFlow from github as ../tensorflow doesn't exist"
  (cd .. && git clone https://github.com/tensorflow/tensorflow)
fi

(cd ../tensorflow &&
 git checkout "${DV_CPP_TENSORFLOW_TAG}" &&
 echo | ./configure)

note_build_stage "build-prereq.sh complete"
