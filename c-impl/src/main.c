#include <stddef.h>
#include <unistd.h>
#include <stdlib.h>

#define EOF (-1)
#define STDOUT_FILENO 1
#define O_RDONLY 0
#define SEEK_SET 0
#define SEEK_CUR 1

#define BUFF_SIZE 1024

char buffer[BUFF_SIZE] = {0};


// Get the maximum length of a line in a file
// Steps:
// - Read buffer from file
// - Iterate through buffer
//   - If character is newline, check if length is greater than max_length
//   - If character is not newline, increment length
// - Return max_length
size_t max_line_length(int fd) {
    size_t max_length = 0;
    size_t length = 0;
    ssize_t bytes_read = 0;
    size_t i = 0;
    while (1) {
        // Read buffer from file
        bytes_read = read(fd, buffer, BUFF_SIZE);
        if (bytes_read == 0) {
            break;
        }
        // Iterate through buffer
        for (i = 0; i < bytes_read; i++) {
            max_length = (buffer[i] == '\n' && length > max_length) ? length : max_length;
            length = (buffer[i] == '\n') ? 0 : length + 1;
        }
    }
    return max_length;
}

// Get the length of the next line in a file and seek to the line start
// Steps:
// - Read buffer from file
// - Iterate through buffer
//   - If character is newline, seek to start of line and return length
//   - If character is not newline, increment length
// - Return -1 if no newline is found
ssize_t get_line_length(int fd) {
    ssize_t length = 0;
    ssize_t seekback = 0;
    ssize_t bytes_read = 0;
    size_t i = 0;
    while (1) {
        // Read buffer from file
        bytes_read = read(fd, buffer, BUFF_SIZE);
        if (bytes_read == 0) {
            return -1;
        }
        seekback += bytes_read;
        // Iterate through buffer
        for (i = 0; i < bytes_read; i++) {
            if (buffer[i] == '\n') {
                lseek(fd, -seekback, SEEK_CUR);
                return length;
            } else {
                length++;
            }
        }
    }
    return -1;
}

// Display whitespace
// Steps:
// - Append ' ' to buffer count times
// - Write buffer to stdout 
void display_whitespace(int fd, size_t count) {
    size_t written = 0;
    size_t i = 0;
    while (written < count) {
        size_t to_write = count - written;
        to_write = (to_write > BUFF_SIZE) ? BUFF_SIZE : to_write;
        for (i = 0; i < to_write; i++) {
            buffer[i] = ' ';
        }
        written += write(STDOUT_FILENO, buffer, to_write);
    }
}

// Display a line from a file
// Steps:
// - Read chunk from file
// - Write chunk to stdout
// - Repeat
void display_line(int fd, ssize_t length) {
    ssize_t bytes_read = 0;
    size_t to_read = 0;
    while (length > 0) {
        to_read = length;
        to_read = (to_read > BUFF_SIZE) ? BUFF_SIZE : to_read;
        bytes_read = read(fd, buffer, to_read);
        write(STDOUT_FILENO, buffer, bytes_read);
        length -= bytes_read;
    }
}


// Display numbers from a file
// Steps:
// - Get the length of the next line
// - If length is -1, return
// - Read the line from the file
// - repeat ' ' max_length - length times
// - Write the line to stdout
// - Repeat
void display_numbers(int fd, size_t max_length) {
    ssize_t length = 0;
    while (1) {
        length = get_line_length(fd);
        if (length == -1) {
            return;
        }
        write(STDOUT_FILENO, "|", 1);
        display_whitespace(fd, max_length - length);
        display_line(fd, length);
        read(fd, buffer, 1); // Read newline character
        write(STDOUT_FILENO, "|\n", 2);
    }
}

int main() {
    int fd = open("numbers.txt", O_RDONLY);
    if (fd < 0) {
        perror("Error opening file");
        exit(1);
    }
    size_t max_length = max_line_length(fd);
    lseek(fd, 0, SEEK_SET);
    display_numbers(fd, max_length);
    close(fd);
    return 0;
}
