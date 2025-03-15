FROM archlinux:base-devel
RUN pacman -Sy lua fcgi --noconfirm
RUN pacman -Sy zig --noconfirm
WORKDIR /app
COPY . .
RUN zig build --release=fast
WORKDIR /www
RUN pacman -Rn zig clang18 compiler-rt18 libedit lld18 llvm18-libs --noconfirm
ENTRYPOINT ["/app/zig-out/bin/lhp"]
EXPOSE 7777