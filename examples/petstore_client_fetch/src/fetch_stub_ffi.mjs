export function install() {
  globalThis.fetch = async function (_request) {
    return new globalThis.Response(
      JSON.stringify([
        { id: 1, name: "Fido", status: "available", tag: "dog" },
        { id: 2, name: "Whiskers", status: "pending" },
      ]),
      {
        status: 200,
        headers: {
          "content-type": "application/json",
        },
      },
    );
  };
}
