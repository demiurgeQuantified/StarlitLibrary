Mod translations
================
Starlit Library allows mods to translate their ``mod.info`` information.
The user must have the library enabled on the main menu for these translations to appear.

Translations are defined with json files in the ``common/modTranslations`` directory.
The file name should be the language code that vanilla translations use for that language in full lowercase.
For example, english translations should use ``common/modTranslations/en.json``.

Translations are supported for ``name``, ``description``, and ``posters`` (in case these have text in them).
You don't have to specify every field:
for example, if your posters don't have text in them don't include the ``posters`` field in your file.

You don't have to provide a translation for every language,
any language that does not have a translation file will default to what's in the ``mod.info``.

Example
-------
.. code-block:: json

    {
        "name": "Test Translation",
        "description": "lololol",
        "posters": [
            "poster_en.png"
        ]
    }
