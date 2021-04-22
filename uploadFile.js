require('dotenv').config()
const pinataApiKey = process.env.API_KEY;
const pinataApiSecret = process.env.API_SECRET;
const axios = require('axios').default;
var FormData = require('form-data');
var fs = require('fs');
var args = process.argv.slice(2);
var filePath = args[0];
const uploadFile = async () => {
  const url = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  let data = new FormData();
  data.append('file', fs.createReadStream(filePath));
  const res = await axios.post(url, data, {
    maxContentLength: 'Infinity',
    headers: {
      'Content-Type': `multipart/form-data;boundary=${data._boundary}`,
      pinata_api_key: pinataApiKey,
      pinata_secret_api_key: pinataApiSecret,
    },
  });
  console.log(res.data);
};
uploadFile();
