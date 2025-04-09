const fs = require("fs");
const { execSync } = require("child_process");

const stdout = execSync("git diff --cached --name-status", {
  encoding: "utf8",
});

const diff = stdout
  .split(/[\r\n]+/)
  .filter((n) => /\.lua$/.test(n))
  .map((row) => {
    return {
      method: row.split(/[\t\s]+/)[0],
      filename: row.split(/[\t\s]+/)[1],
    };
  });

const oldList = JSON.parse(fs.readFileSync("./list.json", "utf8"));

const newFiles = diff
  .filter((f) => f.method === "M" || f.method === "A")
  .map(({ filename }) => {
    version = parseInt(
      fs.readFileSync(filename, "utf8").split(/--\s?(\d+)/)[1]
    );
    return {
      name: filename,
      version,
    };
  });

const removedFiles = diff
  .filter((f) => f.method === "D")
  .map(({ filename }) => filename);

const allCorrect = newFiles.every((newFile) => {
  const oldFile = oldList.find((f) => f.name === newFile.name);
  const correct = !(oldFile && oldFile.version >= newFile.version) && newFile.version > 0;
  if (!correct) {
    console.error(`Version in ${newFile.name} must be updated`);
  }
  return correct;
});

if (allCorrect) {
  console.log(
    `Updating ${diff.length} file record${diff.length === 1 ? "" : "s"}`
  );
  fs.writeFileSync(
    "./list.json",
    JSON.stringify(
      oldList
        .filter(({ name }) => !removedFiles.includes(name))
        .reduce((newList, oldFile) => {
          return newList.find((f) => f.name === oldFile.name)
            ? newList
            : newList.concat([oldFile]);
        }, newFiles)
        .sort((a, b) => (a.name > b.name ? 1 : a.name < b.name ? -1 : 0))
    )
  );
  execSync("git add list.json ");
  process.exit(0);
} else {
  process.exit(1);
}
