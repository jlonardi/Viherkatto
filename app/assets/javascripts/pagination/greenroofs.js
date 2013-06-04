/**
 * Created with JetBrains RubyMine.
 * User: vito
 * Date: 3.6.2013
 * Time: 13:13
 * To change this template use File | Settings | File Templates.
 */
$(document).ready(function () {

    (function () {
        getGreenroofs();
    })();


    function paginate(entry_count, page, per_page) {
        var total = Math.ceil(entry_count / per_page);
        $('.pagination').empty()
        $('.pagination').bootpag({
            total: total,
            page: page,
            maxVisible: 10
        }).on('page', function (event, num) {
                getGreenroofs(num, per_page)
            });
    }

    function getGreenroofs(page, per_page, onDelete) {
        var reloadPaginateNeeded = false;
        if (page === undefined && per_page === undefined) reloadPaginateNeeded = true;
        if (page === undefined) page = 1;
        if (per_page === undefined)  per_page = 20;
        if (onDelete === undefined)  onDelete = false;

        if (onDelete) reloadPaginateNeeded = onDelete;

        $.getJSON("/greenroofs.json?page=" + page + "&per_page=" + per_page, function (data) {

            var entry_count = data["count"];
            var greenroofs = data["greenroofs"];
            var users = data["user"];

            if (greenroofs.length === 0) {
                reloadPaginateNeeded = true
                page -= 1
            }
            if (reloadPaginateNeeded) {
                paginate(entry_count, page, per_page)
                console.log("reloading pagination")
                reloadPaginateNeeded = false;
            }
            // Clears the greenroof list.
            $('.greenroof-list').empty();
            // And lists the queried greenroofs.
            $.each(greenroofs, function (i, item) {
                addGreenroofElement(item, findUserById(item.user_id, users));
            });
        });
    }

    function findUserById(grUser, users) {
        var jsonArray = JSON.parse(users);
        var palautettava = "Username not found";

        $.each(jsonArray, function (i, item) {
            console.log(grUser);
            console.log(item["id"]);
            if (item["id"] == grUser) {
                console.log("if onnistui");
                palautettava = item["name"];
                return false;
            }
        });
        return palautettava;
    }

    function addGreenroofElement(entry, user) {
        console.log("lisätään katto numero " + entry.id)

        var listElement = $('<li></li>');
        var greenroofLink = $('<a href=\"/greenroofs/' + entry.id + '\">' + "Käyttäjän " + user + " viherkatto" + '</a>');
        listElement.append(greenroofLink);
        listElement.append(' | ');
        var deleteElement = $('<a href=\"#\" id=\"/greenroofs/' + entry.id + '\">' + 'poista' + '</a>')
        listElement.append(deleteElement).append(' | ');
        var editElement = $('<a href=\"/greenroofs/' + entry.id + '/edit\">' + 'muokkaa' + '</a>');
        listElement.append(editElement);

        $('.greenroof-list').append(listElement);
    }

    function addGreenroofElementForSearch(entry) {

        var listElement = $('<li></li>');
        var greenroofLink = $('<a href=\"/greenroofs/' + entry.id + '\">' + entry.user_id + '  </a>');
        listElement.append(greenroofLink);
        listElement.append('<i class=\"icon-plus pull-right\"></i>');
        $('.greenroof-list').append(listElement);
    }

    var $cells = $("li");
    var greenroofdata = [];

    $("#search").keyup(function () {
        $('.greenroof-list').empty();
        if (greenroofdata.length === 0) {
            $.getJSON("/greenroofs.json", function (data) {
                greenroofdata = data["greenroofs"];
                console.log(greenroofdata);
            });
        }

        $.each(greenroofdata, function (i, item) {
            var searchword = $("#search").val();
            if (item.name.toLocaleLowerCase().indexOf(searchword) >= 0) {
                addGreenroofElementForSearch(item);
            }
            console.log(searchword);
            console.log(item.name);
        });
    });

});

