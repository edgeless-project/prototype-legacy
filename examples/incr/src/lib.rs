type Error = Box<dyn std::error::Error>;

pub fn handle(body: Vec<u8>) -> Result<Vec<u8>, Error> {
    let string = String::from_utf8(body)?;
    let mut number = string.parse::<i32>()?;
    number += 1;
    Ok(format!("{}", number).as_bytes().to_vec())
}
