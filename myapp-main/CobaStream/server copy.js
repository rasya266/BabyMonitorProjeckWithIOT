const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(express.static('public'));

io.on('connection', (socket) => {
    console.log('a user connected');

    socket.on('disconnect', () => {
        console.log('user disconnected');
    });

    socket.on('offer', (offer) => {
        socket.broadcast.emit('offer', offer);
        console.log(offer);
    });

    socket.on('answer', (answer) => {
        console.log(answer);
        socket.broadcast.emit('answer', answer);
    });

    socket.on('candidate', (candidate) => {
        console.log('candidate', candidate);
        socket.broadcast.emit('candidate', candidate);
    });
});

server.listen(3000, () => {
    console.log('listening on *:3000');
});
