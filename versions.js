const fs = require('fs');

const files = fs.readdirSync('./').filter(name => (/\.lua$/).test(name))
    .map(filename => {
        version = parseInt(fs.readFileSync(filename, 'utf8').split(/--(\d+)/)[1])
        return {
            name: filename,
            version
        }
    });
console.log(`Updating versions for ${files.length} files`)
fs.writeFileSync('./list.json', JSON.stringify(files))