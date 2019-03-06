args <- commandArgs(TRUE)
input_file_name = args[1]
output_file_name = args[2]
output_type = args[3]

data = read.table(input_file_name,header=F,sep=',')

if (output_type == "png") {
    output_file_name <- paste(output_file_name, ".png",sep="")
    png(output_file_name,width=500,height=500)
} else if (output_type == "pdf") {
    output_file_name <- paste(output_file_name, ".pdf",sep="")
    pdf(output_file_name,height=5,width=5,paper="letter",pagecentre=TRUE)
} else if (output_type == "jpg") {
    output_file_name <- paste(output_file_name, ".jpg",sep="")
    jpeg(output_file_name)
}

plot(data[,1],data[,2],xlab="position",ylab="score",type="l")
