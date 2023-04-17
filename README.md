# A tools for migrate markdown image

Before migrate, you must backup your markdown files.

Before migrate, you must backup your markdown files.

Before migrate, you must backup your markdown files.

## ScreenShot

<img width="2051" alt="image" src="https://user-images.githubusercontent.com/14145407/232367336-af93cef6-0a45-45e7-9688-da3c695e9348.png">

## Install

### For Releases

Download the binary file from [release](https://github.com/CaiJingLong/md_picture_migrate_cli/releases)

And unzip the tar.gz file.

If the file is not executable, you can use the following command to make it executable.

```bash
chmod +x mdm.exe
mv mdm.exe /usr/local/bin/mdm # or other path
```

### For dart pub

```bash
dart pub global activate md_picture_migrate_cli
```

## Config

### Azure git

```bash
mdm config --azure-endpoint "https://dev.azure.com/user/images/_git/MirrorImages" --azure-token <person-token> --azure-user <user-name>
```

### Github

```bash
mdm config --github-endpoint "https://github.com/CaiJingLong/md_picture_migrate_cli" --github-token <token> --github-user <username>
```

## Usage

### Scan

```bash
Scan and list all pictures.

Usage: md_picture_migrate_cli scan [arguments]
-d, --directory              The directory to scan.
-i, --include-prefix         The prefix of the picture url to include.
                             (defaults to "http://", "https://")
-x, --exclude-prefix         The prefix of the picture url to exclude.
-e, --markdown-extensions    The file extensions to include.
                             (defaults to ".md", ".markdown")
-h, --help                   Print this usage information.

Run "mdm help" to see global options.
```

Will create need replace image url list.

```bash
mdm scan -d ~/blogs/content -x https://dev.azure.com -x https://cdn.jsdelivr.net
```

### Migrate

```bash
mdm migrate -d ~/blogs/content
```

## help

```bash
mdm -h # or mdm --help
```

## LICENSE

[MIT](LICENSE)
