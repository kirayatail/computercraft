const fs = require('fs');

const oldList = JSON.parse(fs.readFileSync('./list.json', 'utf8'))
console.log('args', process.argv)

const newFiles = process.argv.slice(2).filter(n => (/\.lua$/).test(n))
.map(filename => {
  version = parseInt(fs.readFileSync(filename, 'utf8').split(/--(\d+)/)[1])
  return {
    name: filename,
    version
  }
});

console.log(newFiles);

const correctUpdate = newFiles.every(newFile => {
  const oldFile = oldList.find(f => f.name === newFile.name);
  return !(oldFile && oldFile.version >= newFile.version)
});

if (correctUpdate) {
  console.log(`Updating ${newFiles.length} file records`);
  fs.writeFileSync('./list.json', JSON.stringify(
    oldList.reduce((newList, oldFile) => {
      return (newList.find(f => f.name === oldFile.name)) ? newList : newList.concat([oldFile]);
    }, newFiles)
  ));
  return 0;
} else {
  console.error('File versions must be updated')
  return 1;
}
