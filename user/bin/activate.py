#!@python3@/bin/python3

import json
import os
import os.path
import shutil
import subprocess
import sys


def main(argv) -> int:
    files = {
        os.path.join(os.environ['@topDirEnvVar@'], k): v
        for k, v in json.loads('@configs@').items()
    }

    if '@topDirEnvVar@' == 'HOME':
        ret = subprocess.run([
            '@nix@/bin/nix-env',
            '--set',
            '@profile@',
        ])
        if ret.returncode != 0:
            return ret.returncode

    if '@topDirEnvVar@' == 'out':
        os.makedirs(os.environ['out'], exist_ok=True)
    for link_name, target in files.items():
        if (
            os.path.lexists(link_name)
            and os.path.islink(link_name)
            and os.readlink(link_name) == target
        ):
            continue
        if os.path.lexists(link_name):
            if os.path.isdir(link_name) and not os.path.islink(link_name):
                shutil.rmtree(link_name)
            else:
                os.remove(link_name)
        # Make parent directories ourself for correct umask
        os.makedirs(os.path.dirname(link_name), exist_ok=True)
        if '@topDirEnvVar@' == 'out':
            os.symlink(target, link_name)
        else:
            ret = subprocess.run(
                [
                    '@nix@/bin/nix-store',
                    '--add-root',
                    link_name,
                    '--indirect',
                    '--realise',
                    target,
                ],
                # Avoid printing targets when creating symlinks
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if ret.returncode != 0:
                print(ret.stderr, file=sys.stderr)
                return ret.returncode

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
