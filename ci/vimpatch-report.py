#!/usr/bin/python3

import html
import requests
import os
import string


def get_open_pullrequests():
    pr_item = string.Template('<li><a href="${html_url}">${title}</a></li>')
    url = "https://api.github.com/repos/neovim/neovim/pulls?state=open&per_page=100"
    headers = {
        "User-Agent": "neovim/bot-ci",
    }
    r = requests.get(url, headers)
    r.raise_for_status()

    def stringify(pr):
        return pr_item.substitute(
            html_url=pr["html_url"], title=html.escape(pr["title"])
        )

    prs = sorted(
        (
            {"html_url": pull["html_url"], "title": pull["title"]}
            for pull in r.json()
            if "vim-patch" in pull["title"]
        ),
        key=lambda x: x["title"],
    )
    return "\n".join(map(stringify, prs))


tag_link = string.Template(
    '<li><a href="https://github.com/vim/vim/tree/v8.0.${patch}">vim-patch:8.0.${patch}</a></li>'
)


def linkify_numbers(s):
    return tag_link.substitute(patch="{:04d}".format(int(s)))


def body_template_path():
    return os.path.join(
        os.getenv("BUILD_DIR"), "templates", "vimpatch-report", "body.sh.html"
    )


def version_path():
    return os.path.join(os.getenv("NEOVIM_DIR"), "src", "nvim", "version.c")


def parse_patches():
    # Get patch information from src/nvim/version.c
    #   - merged patches:   listed in version.c
    #   - unmerged patches: commented-out in version.c
    #   - N/A patches:      commented-out with "//123 NA"
    in_patches = False
    merged = []
    not_merged = []
    not_applicable = []
    with open(version_path(), "r", encoding="utf-8") as fd:
        for ln in fd:
            if not in_patches:
                in_patches = "static const int included_patches" in ln
                continue
            if "}" in ln:
                break
            ln = ln.strip(", \n")
            if ln.startswith("//"):
                if ln.endswith("NA"):
                    not_applicable.append(
                        linkify_numbers(ln.replace("//", "").replace("NA", ""))
                    )
                else:
                    not_merged.append(linkify_numbers(ln.replace("//", "")))
            else:
                merged.append(linkify_numbers(ln))

    return ("\n".join(merged), "\n".join(not_merged), "\n".join(not_applicable))


if __name__ == "__main__":
    pull_requests = get_open_pullrequests()
    (merged, not_merged, not_applicable) = parse_patches()
    with open(body_template_path(), "r", encoding="utf-8") as fd:
        template = string.Template(fd.read())
        print(
            template.substitute(
                pull_requests=pull_requests,
                merged=merged,
                not_merged=not_merged,
                not_applicable=not_applicable,
            )
        )
