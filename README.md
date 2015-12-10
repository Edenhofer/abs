# PKGBUILDs for the [Arch User Repository](https://aur.archlinux.org)
Includes control scripts for managing AUR packages. Requires @falconindy's [pkgbuild-introspection](https://www.archlinux.org/packages/community/any/pkgbuild-introspection) tools to auto-generate .SRCINFO

## The idea behind the structure of this repo
Commit PKGBUILDs in named subdirectories. Export them to the AUR with the included `aurpublish` script, using the subtree push stratagem. This preserves an independent history for third-party hosting, pull requests... ;)

## Commands
* Push PACKAGE to the AUR: `./aurpublish PACKAGE`
> -p, --pull&nbsp;&nbsp;&nbsp;&nbsp;instead of publishing, pull changes from the AUR. Can import packages into a new subtree.
>
> -s, --speedup&nbsp;&nbsp;&nbsp;&nbsp;speedup future publishing by recording the subtree history during a push. This creates a merge commit and a second copy of all commits in the subtree. For more details, see the "--rejoin" option in git subtree.
>
> -h, --help&nbsp;&nbsp;&nbsp;&nbsp;show this usage message

* Adding commit hooks
> \#!/bin/sh<br>
> shopt -s nullglob<br>
> for hook in \*.hook; do<br>
> &nbsp;&nbsp;&nbsp;&nbsp;ln -sf "$(pwd)/${hook}" ".git/hooks/${hook%.hook}"<br>
> done

* Adding ssh-config rules
> Add these few lines to your ssh configuration file (~/.ssh/config) and fill in the appropriate path to your AUR key file.<br>
> *Host aur aur.archlinux.org<br>*
> *&nbsp;&nbsp;&nbsp;&nbsp;User aur<br>*
> *&nbsp;&nbsp;&nbsp;&nbsp;Hostname aur.archlinux.org<br>*
> *&nbsp;&nbsp;&nbsp;&nbsp;IdentityFile <PATH TO YOUR AUR KEY>*

## Hooks
* pre-commit
> Reject whitespace errors, and auto-generate .SRCINFO for all changed PKGBUILDs.

* prepare-commit-msg
> Prefill the commit message with a list of updated packages + versions (if any).

## Author

Gordian Edenhofer

## License

Unless otherwise stated, the files in this project may be distributed under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version. This work is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) and [version 3] (https://www.gnu.org/copyleft/gpl-3.0.html) of the GNU General Public License for more details.
