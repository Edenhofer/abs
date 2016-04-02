# PKGBUILDs for the [Arch User Repository](https://aur.archlinux.org)
Additionally this repo includes control scripts for managing AUR packages.

## The idea behind the structure of this repo
Commit PKGBUILDs in named subdirectories. Export them to the AUR with the included `aurpublish` script, using git subtrees. This preserves an independent history for third-party hosting and pull requests without losing the ability to manage all packages in one repo.

## Commands
* Push or pull packages to or from the AUR using `./aurpublish [OPTIONS] PACKAGE(s)`
```
-p, --pull <package(s)>      Pull changes or import a new package from the AUR
-g, --git '<git options>'    Pass additional options to git (in brackets)
-h, --help                   Show a help message
```
Git, which is invoked by aurpublish, needs to know with which ssh-key you would like to authenticate to the AUR server. Therefore you must either specify your key through the command line or alter you ssh-configuration accordingly - Refer to 'Adding ssh-config rules' for more details.

* Adding git-hooks (through bash)
```bash
for hook in $(git rev-parse --show-toplevel)/*.hook; do
    (cd "$(git rev-parse --show-toplevel)"
        && ln -s "../../$(basename ${hook})" ".git/hooks/$(basename ${hook%.hook})");
done
```

* Suggested: Adding ssh-config rules (to ~/.ssh/config)
```
Host aur aur.archlinux.org
    User aur
    Hostname aur.archlinux.org
    IdentityFile <PATH_TO_YOUR_AUR_KEY>
```

## Hooks
* pre-commit
> Reject whitespace errors, and auto-generate .SRCINFO for all changed PKGBUILDs.

* prepare-commit-msg
> Prefill the commit message with a list of updated packages + versions (if any).

## Author

Gordian Edenhofer

## License

Unless otherwise stated, the files in this project may be distributed under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version. This work is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) and [version 3] (https://www.gnu.org/copyleft/gpl-3.0.html) of the GNU General Public License for more details.
