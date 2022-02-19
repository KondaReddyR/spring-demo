package com.rhels.demo;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.Arrays;

@Controller
public class GreetingController {

    @GetMapping
    public String greeting(Model model) {
        model.addAttribute("name", "SomeValue");
        model.addAttribute("people", Arrays.asList(
                new Person("A", 1),
                new Person("B", 2),
                new Person("C", 3)
        ));
        return "greeting";
    }
}