use serde::{Deserialize, Serialize};
type Error = Box<dyn std::error::Error>;

#[derive(Serialize, Deserialize)]
struct Argument {
    input: i32,
}

#[derive(Serialize, Deserialize)]
struct Return {
    output: i32,
}

pub fn handle(body: Vec<u8>) -> Result<Vec<u8>, Error> {
    let a: Argument = serde_json::from_str(String::from_utf8(body)?.as_str())?;

    let r = Return {
        output: a.input + 1,
    };

    Ok(serde_json::to_string(&r)?.as_bytes().to_vec())
}
