# Stage 1: Build the binary
FROM golang:alpine AS builder

RUN apk add --no-cache gcc musl-dev git
# Create appuser.
ENV USER=scratchuser
ENV UID=10001 
# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"
# Set the working directory inside the container
WORKDIR /app
# Copy dependency files first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application (disabling CGO for a static binary)
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/api/main.go

# CMD ["./main"]
# Create the final image, running the API and exposing port 8080
FROM scratch

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/main /bin/server
COPY --from=builder /etc/passwd /etc/passwd

USER scratchuser
# Expose the application port
ARG PORT
ENV PORT=$PORT
EXPOSE $PORT

# Command to run the application
ENTRYPOINT ["/bin/server"]