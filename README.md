This repository contains my write-along code, elaborations, experiments, and reference work from working through the book *Terraform: Up and Running, Third Edition* (Yevgeniy Brikman, 2022)

My code is not 100% to the letter of the book. Sometimes because of preference, sometimes because of external reasons (such as launch configurations not being available to an AWS free tier account). I have also added things here and there, such as [this Powershell script](/terraform-practice/chapter-04/destroy-all.ps1) to perform the `terraform destroy` command on multiple Terraform configurations (the book talks about Terragrunt being a solution for such cases, but I wanted to experiment with Powershell). When some code is significantly altered from the example code, I flag it with `# ALTERED`

The original code samples can be found in this [public repository](https://github.com/brikis98/terraform-up-and-running-code)

## Fair Use
Brikman writes the following about the usage of the code samples from the book:

>#### Using the Code Examples
>If you have a technical question or a problem using the code examples, please send email to bookquestions@oreilly.com.
>
>This book is here to help you get your job done. In general, if example code is offered with this book, you may use it in your programs and documentation. You do not need to contact us for permission unless you’re reproducing a significant portion of the code. For example, writing a program that uses several chunks of code from this book does not require permission. Selling or distributing examples from O’Reilly books does require permission. Answering a question by citing this book and quoting example code does not require permission. Incorporating a significant amount of example code from this book into your product’s documentation does require permission.
>
>We appreciate, but generally do not require, attribution. An attribution usually includes the title, author, publisher, and ISBN. For example: “Terraform: Up and Running, Third Edition by Yevgeniy Brikman (O’Reilly). Copyright 2022 Yevgeniy Brikman, 978-1-098-11674-3.”
>
>If you feel your use of code examples falls outside fair use or the permission given above, feel free to contact O’Reilly Media at permissions@oreilly.com
