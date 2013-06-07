$(document).ready(function () {
    var paginator = new Pagination("plants")

    paginator.getObjects()
});


var addElement = function (entry, admin) {
    var listElement = $('<li></li>');
    var link = $('<a href=\"/' + this.object + 's/' + entry.id + '\">' + entry.name + '</a>');
    listElement.append(link);
//    console.log(admin)
    if (admin) {
        listElement.append(' | ');
        var deleteElement = $('<a href=\"#\" id="/' + this.object + 's/' + entry.id + '\">' + 'poista' + '</a>').click(this.deleteRequest);
        listElement.append(deleteElement).append(' | ');
        var editElement = $('<a href=\"/' + this.object + 's/' + entry.id + '/edit\">' + 'muokkaa' + '</a>');
        listElement.append(editElement);
    }
    $('.' + this.object + '-list').append(listElement);
}