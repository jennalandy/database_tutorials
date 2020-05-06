# Writing Pages
- Number pages in order. 
- Page title is defined by `#` top markdown header.
- Subsections defined by lower markdown headers.

# Knitting Book
Run the following commands in the `bookdown` directory:

```
library(bookdown)
render_book("index.Rmd", output_dir = "../docs")
```

The knitted book will be saved as `/docs/index.html` and, when pushed to github, will be published on the [github io page](https://jennalandy.github.io/stat400_database_tutorials/).